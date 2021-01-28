# Web based QR authentication example

On this example you can see how you can implement Self based QR authentication feature.

## How to run it

Before even starting, you have to create your Self-App and generate your key-pair through [developer portal](https://developer.selfid.net/)

Once you have your self keys, you can run this example using docker
```dockerfile
$ docker build -t self-qr-auth-demo .
$ docker run -p 4567:4567 -e SELF_APP_ID=<self-app-id> -e SELF_APP_DEVICE_SECRET=<self-app-secret> self-qr-auth-demo
```  

If everything is working fine you should be able to [open your browser](http://localhost:4567) and start interacting with self authentication feature. 