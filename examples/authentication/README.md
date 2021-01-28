# SelfID based authentication request

A Self user will be authenticated on your platform by only providing its _SelfID_ and accepting the authentication request on his phone.

As part of this process, you will provide users with a user interface so they can fill their _SelfID_.

Due of its nature the authentication is an asynchronous process, where your program should wait for user's input before authenticating it. This process is fully managed by `authenticate` gem function.

## Running this example

In order to run this example, you must have a valid app keypair. Self-keypairs are issued by [Self Developer portal](https://developer.selfid.net/) when you create a new app.

Once you have your valid `SELF_APP_ID` and `SELF_APP_DEVICE_SECRET` you can run this example with:

```bash
$ SELF_APP_ID=XXXXX SELF_APP_DEVICE_SECRET=XXXXXXXX ruby app.rb <your_self_id>
```
or you can try a blocking approach on
```bash
$ SELF_APP_ID=XXXXX SELF_APP_DEVICE_SECRET=XXXXXXXX ruby blocking.rb <your_self_id>
```

Note you must provide a valid user self_id `your_self_id`, this exqample will send an authentication request to this self_id, so keep an eye on the user's device to look for a authentication request.


## Process diagram

This diagram shows how does a SelfID authentication request process works internally.

![Diagram](https://static.joinself.com/images/authentication_diagram.png)

1. Request specific user authentication through self-sdk
2. Self-SDK will send the authentication request to the specified user.
3. The user sends back a signed approved response
4. Self SDK verifies the response has been signed by the user based on its public keys.
5. Your app gets an approved verified auth response

