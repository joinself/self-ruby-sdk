# SelfID based information request

Your app can request certain bits of information to your connected users. To do this, you'll only need its _SelfID_ and the fields you want to request you can find a list of updated valid fields [here](https://github.com/selfid-net/selfid-gem/blob/master/lib/sources.rb).

Due of its nature the information request is an asynchronous process, where your program should wait for user's input before processing the response. This process is fully managed by `request_information` gem function.

## Running this example

In order to run this example, you must have a valid app keypair. Self-keypairs are issued by [Self Developer portal](https://developer.selfid.net/) when you create a new app.

Once you have your valid `SELF_APP_ID` and `SELF_APP_SECRET` you can run this example with:

```bash
$ SELF_APP_ID=XXXXX SELF_APP_SECRET=XXXXXXXX ruby app.rb <your_self_id>
```

Note you must provide a valid user self_id `your_self_id`, this exaample will send an information request to this self_id, so keep an eye on the user's device to look for an information request.


## Process diagram

This diagram shows how does an authentication process wrk internally.

![Diagram](diagram.png)


1. Request information through the self SDK
2. SDK will send an information request to a user already connected to you.
3. The user will select the requested facts and accept sharing them with you.
4. The user’s device will send back a signed response with specific facts
5. Self SDK verifies the response has been signed by the user based on its public keys.
6. Self SDK verifies each fact is signed by the user/app specified on each fact.
7. Your app gets a verified response with a list of requested verified facts.


