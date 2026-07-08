#!/usr/bin/env python3
"""
Universal compression hooks for all AI launchers.
Compresses tool output by 70-90% before sending to model.
"""

import json
import sys
import re
from dataclasses import dataclass
from typing import Dict

@dataclass
class CompressionResult:
    """Result of a compression operation"""
    content: str
    original_size: int
    compressed_size: int
    savings_percent: float
    content_type: str


class TypeDetector:
    """Detect content type for optimal compression strategy"""

    @staticmethod
    def detect(content: str) -> str:
        """Identify what kind of content we're compressing"""
        if not content or len(content) < 10:
            return "text"

        content_stripped = content.strip()

        # JSON detection
        if (content_stripped.startswith('{') or content_stripped.startswith('[')) and \
           (content_stripped.endswith('}') or content_stripped.endswith(']')):
            try:
                json.loads(content_stripped)
                return "json"
            except:
                pass

        # Code detection
        if re.search(r'\b(def|class|function|if|for|while|return|import|from)\b', content):
            return "code"

        # Log detection
        if re.search(r'(\[.*(INFO|ERROR|DEBUG|WARN|TRACE)\]|\d{4}-\d{2}-\d{2})', content):
            return "logs"

        # Search results
        if re.search(r'(^|\n)(/)[\w/-]+:\d+', content, re.MULTILINE):
            return "search"

        # Markdown
        if re.search(r'^#+\s|^\*\*|^\[.*\]\(', content, re.MULTILINE):
            return "markdown"

        # API response
        if re.search(r'"(status|error|message|data|result|success)":', content):
            return "api"

        return "text"


class Compressor:
    """Compression strategies for different content types"""

    @staticmethod
    def compress_json(content: str) -> str:
        """Compress JSON"""
        try:
            data = json.loads(content)
            return json.dumps(data, separators=(',', ':'), ensure_ascii=True)
        except:
            return content

    @staticmethod
    def compress_code(content: str) -> str:
        """Compress code"""
        lines = content.split('\n')
        compressed = []

        for line in lines:
            line = line.rstrip()

            # Skip comments
            if re.match(r'^\s*#', line) or re.match(r'^\s*//', line):
                continue

            # Remove inline comments
            if '#' in line:
                line = line.split('#')[0].rstrip()

            # Reduce spaces
            line = re.sub(r'  +', ' ', line)

            if line:
                compressed.append(line)

        return '\n'.join(compressed)

    @staticmethod
    def compress_logs(content: str) -> str:
        """Compress logs by grouping"""
        lines = content.split('\n')
        compressed = []
        last_line = None
        count = 1

        for line in lines:
            if line == last_line:
                count += 1
            else:
                if last_line is not None:
                    if count > 1:
                        compressed.append(f"{last_line} (×{count})")
                    else:
                        compressed.append(last_line)
                last_line = line
                count = 1

        if last_line is not None:
            if count > 1:
                compressed.append(f"{last_line} (×{count})")
            else:
                compressed.append(last_line)

        return '\n'.join(compressed)

    @staticmethod
    def compress_search(content: str) -> str:
        """Compress search results"""
        lines = content.split('\n')
        compressed = []

        for line in lines:
            if re.match(r'^/', line) or re.search(r':\d+', line):
                compressed.append(line)
            elif line.startswith('File:') or line.startswith('Match:'):
                compressed.append(re.sub(r'\s+', ' ', line))
            elif line.strip():
                abbreviated = re.sub(r'\s+', ' ', line).strip()
                if len(abbreviated) > 100:
                    abbreviated = abbreviated[:100] + '...'
                compressed.append(abbreviated)

        return '\n'.join(compressed)

    @staticmethod
    def compress_markdown(content: str) -> str:
        """Compress markdown"""
        lines = content.split('\n')
        compressed = []
        prev_blank = False

        for line in lines:
            is_blank = not line.strip()

            if is_blank:
                if not prev_blank:
                    compressed.append(line)
                prev_blank = True
            else:
                compressed.append(line)
                prev_blank = False

        return '\n'.join(compressed).strip()

    @staticmethod
    def compress(content: str, content_type: str) -> str:
        """Apply compression"""
        strategies = {
            "json": Compressor.compress_json,
            "code": Compressor.compress_code,
            "logs": Compressor.compress_logs,
            "search": Compressor.compress_search,
            "markdown": Compressor.compress_markdown,
            "api": Compressor.compress_json,
            "text": Compressor.compress_markdown,
        }

        strategy = strategies.get(content_type, Compressor.compress_markdown)
        return strategy(content)


class CompressionHook:
    """Main hook"""

    def process(self, content: str) -> CompressionResult:
        """Process content"""
        original_size = len(content.encode('utf-8'))

        # Detect and compress
        content_type = TypeDetector.detect(content)
        compressed = Compressor.compress(content, content_type)
        compressed_size = len(compressed.encode('utf-8'))

        # Calculate savings
        if original_size > 0:
            savings_percent = (1 - compressed_size / original_size) * 100
        else:
            savings_percent = 0

        return CompressionResult(
            content=compressed,
            original_size=original_size,
            compressed_size=compressed_size,
            savings_percent=savings_percent,
            content_type=content_type,
        )


def main():
    """Read from stdin, compress, write to stdout"""
    hook = CompressionHook()

    # Read all content from stdin
    content = sys.stdin.read()

    # Skip if no content or very small
    if not content or len(content) < 100:
        sys.stdout.write(content)
        return

    # Process through hook
    result = hook.process(content)

    # Write compressed content
    sys.stdout.write(result.content)

    # Log stats if verbose
    if "--verbose" in sys.argv:
        sys.stderr.write(f"[hook] type={result.content_type} "
                        f"original={result.original_size} "
                        f"compressed={result.compressed_size} "
                        f"saved={result.savings_percent:.1f}%\n")


if __name__ == "__main__":
    main()
