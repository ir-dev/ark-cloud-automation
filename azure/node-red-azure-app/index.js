const express = require("express");
const http = require("http");
const path = require("path");
const RED = require("node-red");

const app = express();
const server = http.createServer(app);
const port = Number(process.env.PORT || 8080);
const userDir = process.env.NODE_RED_USER_DIR || path.join(__dirname, ".node-red");

const settings = {
  httpAdminRoot: "/red",
  httpNodeRoot: "/",
  userDir,
  flowFile: "flows.json",
  functionGlobalContext: {},
  editorTheme: {
    projects: {
      enabled: true
    }
  }
};

RED.init(server, settings);
app.use(settings.httpAdminRoot, RED.httpAdmin);
app.use(settings.httpNodeRoot, RED.httpNode);

app.get("/", (req, res) => {
  res.redirect("/red");
});

server.listen(port, () => {
  console.log(`Node-RED is starting on port ${port}`);
  console.log(`Node-RED userDir: ${userDir}`);
  RED.start()
    .then(() => {
      console.log("Node-RED runtime started successfully.");
    })
    .catch((err) => {
      console.error("Node-RED startup failed:", err);
      process.exit(1);
    });
});

server.on("error", (err) => {
  console.error("Server failed to start:", err);
  process.exit(1);
});
