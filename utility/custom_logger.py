from loguru import logger
import sys
from pathlib import Path


def setup_logger(log_dir: Path):
    log_format = "<green>{time}</green> | <cyan>{file.name}:{line}</cyan> |{level} | {message} | {extra}"

    logger.remove()

    logger.add(
        sys.stderr,
        format=log_format,
        level="TRACE",
    )

    logger.add(
        log_dir / "nse_pulse.log",
        format=log_format,
        level="TRACE",
        rotation="10 MB",
        retention="10 days",
        compression="zip",
    )

    # logger.trace("Trace logs")
    # logger.debug("Debug")
    # logger.info("Info logs")
    # logger.error("Error")
    # logger.critical("Critical")

    return logger
