from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI(title="CATFLOW Project API")
import state

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from api import project, hills, soil, forcing, export, wind, results
from state import current_project

app.include_router(project.router)
app.include_router(hills.router)
app.include_router(soil.router)
app.include_router(forcing.router)
app.include_router(export.router)
app.include_router(wind.router)
app.include_router(results.router)

@app.get("/")
async def root():
    return {
        "service": "CATFLOW Project API",
        "version": "1.0",
        "status": "running",
        "project_loaded": current_project is not None
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)