# Dockerfile

- [Return main to README.md](../../README.md)

the idea is to try re-pack original docker image


```bash
make get-sources

# builder target
clear ; make build-dev && make run-dev

# runtime target
clear ; make build && make run 
```