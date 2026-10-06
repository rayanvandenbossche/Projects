import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  /* config options here */
  output: "standalone",
  reactCompiler: true,
  experimental: {
    allowedRevalidateHeaderKeys: undefined,
  },
  // Allow hot module replacement WebSocket connections from the local hostname
  allowedDevOrigins: ['printportal.soudal.com', 'localhost']
};

export default nextConfig;
