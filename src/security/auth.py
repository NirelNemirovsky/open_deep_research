import os
from langgraph_sdk import Auth


# Minimal permissive auth for local development: always returns a dev identity.
auth = Auth()


@auth.authenticate
async def get_current_user(authorization: str | None) -> Auth.types.MinimalUserDict:
    return {"identity": os.environ.get("DEV_USER_ID", "dev-user")}