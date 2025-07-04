import {
  ApiController,
  ApiError,
  Client,
  Environment
} from 'user-management-apilib';

const client = new Client({
  timeout: 0,
  environment: Environment.Production,
  defaultHost: 'www.example.com',
});

const apiController = new ApiController(client);

const body = {
  name: 'name6',
  email: 'email0',
  address: {
    street: 'street6',
    city: 'city6',
    zip: 'zip0',
  },
  roles: [
    {
      name: 'name2',
      permissions: [
        'permissions9',
        'permissions0',
        'permissions1'
      ],
    }
  ],
};

async function main() {
  try {
    const { result } = await apiController.createANewUser(body);
    console.log(result, "result");
  } catch (error) {
    if (error instanceof ApiError) {
      const errors = error.result;
      console.log(errors, "errors");
    }
    console.log(error, "error");
  }
};

main();
console.log('Hello from Webpack!');
