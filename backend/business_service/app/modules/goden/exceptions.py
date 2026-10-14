from fastapi import status
from fastapi.exceptions import HTTPException


class GodenPointTakenError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Эта точка Goden уже подключена к другому заведению",
        )


class OutletNotBoundError(HTTPException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail="Заведение не подключено к точке Goden",
        )
