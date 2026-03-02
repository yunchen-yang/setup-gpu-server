.PHONY: setup start setup_and_start lightning_setup lightning_start lightning_setup_and_start

setup:
	@bash setup.sh

lightning_setup:
	@bash lightning_setup.sh

start:
	@.venv/bin/uvicorn api:app --host 0.0.0.0 --port $${API_PORT:-8000}

lightning_start:
	@uvicorn api:app --host 0.0.0.0 --port $${API_PORT:-8000}

setup_and_start: setup start

lightning_setup_and_start: lightning_setup lightning_start
