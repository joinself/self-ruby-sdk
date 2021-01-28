# Web based SelfID zero knowledge fact check

On this example you can see how you can implement SelfID fact request feature with an intermediary based on users *SelfID*.

## How to run it

Before even starting, you have to create your Self-App and generate your key-pair through [developer portal](https://developer.selfid.net/)

Once you have your self keys, you can run this example using docker
```dockerfile
$ docker build -t self-intermediary-demo .
$ docker run -p 4567:4567 -e SELF_APP_ID=<self-app-id> -e SELF_APP_DEVICE_SECRET=<self-app-secret> self-intermediary-demo
```  

If everything is working fine you should be able to [open your browser](http://localhost:4567) and start interacting with self authentication feature. 