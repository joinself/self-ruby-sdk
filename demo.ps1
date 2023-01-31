function up {
    docker run --name self-ruby-sdk -t -d --env-file examples/.env -v ${PWD}:/sdk -w /sdk/examples ghcr.io/joinself/self-ruby-sdk
    docker exec self-ruby-sdk bundle install
}

function run {
    docker exec -it self-ruby-sdk bundle exec ruby quickstart.rb
}

function down {
    docker stop self-ruby-sdk
    docker rm self-ruby-sdk
}

function install {
    docker exec -it self-ruby-sdk bundle install
}

function main {
    switch ($args[0]) {
        "up" { up }
        "down" { down }
        "run" { run }
        "install" { install }
    }
}

main $args