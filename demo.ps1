function up {
    docker build --platform linux/amd64 -t rubysdk .
    docker run --platform linux/amd64 --name rubysdk -t -d --env-file examples/.env -v ${PWD}:/sdk -w /sdk rubysdk
    docker exec -w /sdk/examples/ rubysdk bundle install
}

function run {
    docker exec -it -w /sdk/examples/ rubysdk bundle exec ruby quickstart.rb
}

function down {
    docker stop rubysdk
    docker rm rubysdk
}

function main {
    switch ($args[0]) {
        "up" { up }
        "down" { down }
        "run" { run }
    }
}

main $args