import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Images: allow external domains used in the app
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "**" },
      { protocol: "http",  hostname: "**" },
    ],
  },
};

export default nextConfig;
