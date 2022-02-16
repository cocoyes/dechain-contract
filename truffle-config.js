module.exports = {
  networks: {
      development: {
          port: 9545,
          host: "127.0.0.1",
          network_id: "*"
      }
  },
    compilers: {
        solc: {
            //version: "0.5.6"
            version: "0.4.24"
        }
    }
};
