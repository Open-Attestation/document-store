import typescript from "rollup-plugin-typescript2";
import resolve from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";

/**
 * @type {import('rollup').RollupOptions}
 */
const config = {
  input: "output/index.ts",
  output: [
    {
      file: "index.js",
      format: "cjs"
    },
    {
      file: "index.mjs",
      format: "esm"
    }
  ],
  context: "this",
  plugins: [
    resolve(),
    commonjs(),
    typescript({
      tsconfig: "../../tsconfig.json",
      exclude: ["../../hardhat.config.ts"],
      tsconfigOverride: {
        compilerOptions: {
          module: "esnext"
        }
      }
    })
  ]
};

export default config;
