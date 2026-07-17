from loguru import logger
import sys

logger.remove()
logger.add(
    sys.stderr,
    format="<green>{time}</green> | {level} | {message} | {extra}",
    level="TRACE",
)

# for making a seperate file
logger.add(
    "nse_pulse.log",
    level="TRACE",
    rotation="10 MB",
    retention="10 days",
    compression="zip",
)

logger.trace("Trace logs")
logger.debug("Debug")
logger.info("Info logs")
logger.error("Error")
logger.critical("Critical")
