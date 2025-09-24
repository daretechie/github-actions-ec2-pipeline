const request = require("supertest");
const app = require("../src/app");

describe("Application Tests", () => {
  test("GET /api/health should return healthy status", async () => {
    const response = await request(app).get("/api/health").expect(200);

    expect(response.body.status).toBe("healthy");
    expect(response.body.timestamp).toBeDefined();
  });

  test("GET /api/info should return application info", async () => {
    const response = await request(app).get("/api/info").expect(200);

    expect(response.body.name).toBe("GitHub Actions Pipeline Demo");
    expect(response.body.description).toBeDefined();
  });

  test("Static files should be served", async () => {
    await request(app).get("/").expect(200);
  });
});
