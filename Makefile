container = try-alf

ps:
	docker ps

build:
	docker build -t $(container) .

up: 
	docker run -d -p 4000:4000 --rm --name $(container) $(container)
	docker ps

logs:
	docker logs -f $(container)

down:
	docker stop $(container)

restart:
	docker container restart $(container)

clean:
	docker rm try-alf

bash:
	docker exec -it $(container) bash