"""Run a CLI tool in a PTY with output compression.
Gives the child a real TTY (interactive) while still capturing
stdout for CompressionHook processing."""
import os
import sys
import pty
import select
import signal
import struct
import termios
import fcntl


def run(cmd_args, hook=None):
    pid, fd = pty.fork()
    if pid == 0:
        os.execvp(cmd_args[0], cmd_args)
        os._exit(1)

    try:
        _set_winsize(fd)
        signal.signal(signal.SIGWINCH, lambda *_: _set_winsize(fd))

        while True:
            rlist, _, _ = select.select([sys.stdin, fd], [], [])
            for rfd in rlist:
                if rfd == sys.stdin:
                    data = _read(sys.stdin.fileno())
                    if not data:
                        return
                    _write(fd, data)
                else:
                    data = _read(fd)
                    if not data:
                        break
                    data = _compress(data, hook)
                    _write(sys.stdout.fileno(), data)
            else:
                continue
            break
    except KeyboardInterrupt:
        _write(fd, b"\x03")
        try:
            os.waitpid(pid, 0)
        except OSError:
            pass
        os._exit(128 + signal.SIGINT)
    finally:
        try:
            os.waitpid(pid, 0)
        except OSError:
            pass


def _read(fd, size=65536):
    try:
        return os.read(fd, size)
    except OSError:
        return b""


def _write(fd, data):
    try:
        os.write(fd, data)
    except OSError:
        pass


def _set_winsize(fd):
    try:
        size = struct.unpack(
            "HH", fcntl.ioctl(sys.stdin, termios.TIOCGWINSZ, struct.pack("HH", 0, 0))
        )
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HH", *size))
    except Exception:
        pass


def _compress(data, hook):
    if hook and len(data) >= 100:
        try:
            text = data.decode("utf-8")
            result = hook.process(text)
            if result.savings_percent > 10:
                return result.content.encode("utf-8")
        except Exception:
            pass
    return data
