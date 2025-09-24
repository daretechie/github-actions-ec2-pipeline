const request = require("supertest");
const app = require("../src/app");

describe("Application Tests", () => {
  describe("Health Endpoints", () => {
    test("GET /api/health should return healthy status", async () => {
      const response = await request(app).get("/api/health").expect(200);

      expect(response.body.status).toBe("healthy");
      expect(response.body.timestamp).toBeDefined();
      expect(response.body.version).toBeDefined();
      expect(response.body.uptime).toBeDefined();
    });

    test("GET /api/info should return application info", async () => {
      const response = await request(app).get("/api/info").expect(200);

      expect(response.body.name).toBe("GitHub Actions EC2 Pipeline Demo");
      expect(response.body.description).toBeDefined();
      expect(response.body.environment).toBeDefined();
    });

    test("GET /api/status should return server status", async () => {
      const response = await request(app).get("/api/status").expect(200);

      expect(response.body.memory_usage).toBeDefined();
      expect(response.body.platform).toBeDefined();
      expect(response.body.node_version).toBeDefined();
    });
  });

  describe("Static Content", () => {
    test("GET / should serve homepage", async () => {
      await request(app).get("/").expect(200).expect("Content-Type", /html/);
    });

    test("GET /style.css should serve stylesheet", async () => {
      await request(app)
        .get("/style.css")
        .expect(200)
        .expect("Content-Type", /css/);
    });
  });

  describe("Error Handling", () => {
    test("GET /nonexistent should return 404", async () => {
      const response = await request(app).get("/nonexistent").expect(404);

      expect(response.body.error).toBe("Route not found");
    });
  });
});
