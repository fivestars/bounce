"""The API application endpoints."""

import logging
import os

from ddtrace_asgi.middleware import TraceMiddleware
from starlette import status
from starlette.applications import Starlette
from starlette.responses import JSONResponse
from starlette.routing import Route

logger = logging.getLogger()


def startup():
    """Log a simple startup message when the app is loaded."""
    logger.info("Ready to go")


def bounce(request) -> JSONResponse:
    """Bounce the request back in the response."""
    return JSONResponse(
        content={
            "url": str(request.url),
            "headers": dict(request.headers),
            "query_params": dict(request.query_params),
            "path_params": dict(request.path_params),
            "client": request.client,
            "cookies": dict(request.cookies),
        }
    )


def create_app() -> Starlette:
    """Create the API application."""
    app = Starlette(routes=[Route("/{path:path}", bounce)], on_startup=[startup])

    if os.environ["APM_ENABLED"] == "true":
        logger.info("Datadog APM enabled; installing middleware")
        app.add_middleware(TraceMiddleware, service=os.environ["DATADOG_SERVICE_NAME"])

    return app
