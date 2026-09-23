"""Application entry point for irframe_parser."""
import sys


def main():
    if "--self-test-exit" in sys.argv:
        sys.exit(0)
    print("IR Frame Parser Desktop Application")


if __name__ == "__main__":
    main()
