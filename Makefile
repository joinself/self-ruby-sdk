up:
	docker build --platform linux/amd64 -t rubysdk .

run:
	docker run --platform linux/amd64 --name rubysdk -t -d --env-file .env -v $PWD:/sdk -w /sdk rubysdk
	docker exec rubysdk bundle install
	docker exec rubysdk bundle exec ruby examples/chat/app.rb 37456733879



