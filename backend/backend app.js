const express = require("express");
const cors = require("cors");
const productsRoutes = require("./routes/products");

const app = express();
app.use(cors());
app.use(express.json());

app.use("/api/products", productsRoutes);

const PORT = 4000;
app.listen(PORT, () => console.log(`Backend corriendo en http://localhost:${PORT}`));
