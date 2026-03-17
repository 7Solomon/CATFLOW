# Stage 1: Build Fortran
FROM debian:bookworm as fortran-builder
RUN apt-get update && apt-get install -y gfortran make
WORKDIR /src
COPY ./fortran_src .

# Compile and output to /build/catflow
RUN gfortran -o /build/catflow main.f90 ... 

# Stage 2: Python Backend
FROM python:3.11-slim
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy binary from Stage 1
COPY --from=fortran-builder /build/catflow /app/bin/catflow

# Copy backend code
COPY . .

# Environment variables
ENV TEMPLATE_FOLDER=/app/templates
ENV WORKSPACE_DIR=/app/workspaces

CMD ["uvicorn", "main:app", "--host", "0.0.0.0"]
