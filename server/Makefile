.PHONY: setup start setup_and_start

setup:
	@bash setup.sh

start:
	@.venv/bin/uvicorn api:app --host 0.0.0.0 --port $${API_PORT:-8000}

setup_and_start: setup start
