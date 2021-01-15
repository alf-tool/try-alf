CONTAINER = enspirit/try-alf

ps:
	docker ps

image:
	docker build -t $(CONTAINER) .

push-image:
	docker push $(CONTAINER)

up:
	docker run -d -p 4000:4000 --rm --name $(CONTAINER) $(CONTAINER)
	docker ps

logs:
	docker logs -f $(CONTAINER)

down:
	docker stop $(CONTAINER)

restart:
	docker CONTAINER restart $(CONTAINER)

clean:
	docker rm try-alf

bash:
	docker exec -it $(CONTAINER) bash
