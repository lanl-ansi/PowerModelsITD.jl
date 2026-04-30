FROM scratch AS data
COPY . /app

FROM --platform=linux/arm64 python:3.12 AS python-build
COPY ["requirements.txt", "./"]
RUN python -m venv /venv
ENV PATH=/venv/bin:$PATH
RUN pip install --no-cache -r requirements.txt

FROM --platform=linux/arm64 julia:1.12.5 AS julia-build
COPY --from=data /app /app
ENV JULIA_DEPOT_PATH="/julia_depot"

FROM python-build AS main-build
COPY --from=data /app /app
COPY --from=julia-build /usr/local/julia /usr/local/julia

WORKDIR /app
ENV PATH="/usr/local/julia/bin:/venv/bin:${PATH}" \
    JULIA_DEPOT_PATH="/julia_depot" \
    JULIA_PROJECT="/app" \
    PYTHON="/venv/bin/python" \
    PYCALL_JL_RUNTIME_PYTHON="/venv/bin/python"

RUN julia --project=/app -e 'using Pkg; Pkg.instantiate(); ENV["PYTHON"]="/venv/bin/python"; Pkg.build("PyCall")'
RUN python -c "import julia; julia.install();"

CMD ["uvicorn","main:app","--reload","--port","8800","--host","0.0.0.0"]

