# Catalog import template

Fill `products-template.csv` with your real products, delete the four example rows, and upload it in **Back office → Import / Export**. The importer also accepts an `.xlsx` file with the same columns, and a CSV saved by Excel in Indonesian (`;` separators, decimal commas). The same page downloads this template, or your current catalog in the same shape.

The whole file is checked before anything is saved, and every problem is listed with its row number. Nothing changes until the file is clean. Importing the same file again updates the products with those SKUs instead of adding new ones.

| Column | Required | Rules |
|---|---|---|
| `product_name` | yes | Rows with the same product name become one product with several variants |
| `variant_name` | no | Empty means `Default`, for products with no sizes or flavours |
| `sku` | yes | Unique code: letters, digits, `.`, `_` or `-`, up to 40 characters |
| `barcode` | no | EAN-13 or any code your scanner reads. Leave it empty for items sold by weight |
| `category` | yes | Created if it doesn't exist yet. Cashier-screen order is set later in Settings |
| `unit` | yes | One of `pcs`, `kg`, `g`, `l`, `ml`, `pack`, `box`, `dus`, `renceng`, `lusin` |
| `price` | yes | Selling price in whole rupiah with **no dots or "Rp"**: write `25000`, not `Rp 25.000`. With the default store settings this price **includes** PPN 11% |
| `cost` | yes | Purchase cost (HPP) per unit, in whole rupiah |
| `taxable` | no | `yes`/`ya` (the default), or `no`/`tidak` for PPN-exempt goods (beras, gula, telur, fresh produce …) |
| `track_stock` | no | `yes` (the default), or `no` for services or items you never count |
| `reorder_point` | no | A low-stock alert fires at or below this quantity |
| `stock_<STORE CODE>` | no | Opening stock per store, one column per store code (`stock_PST`, `stock_BKS`, `stock_TGR` …). This is the counted stock, not an amount to add, and it is recorded as a stock count (opname). Decimals with a dot or comma are allowed for `kg` / `l` items (`12.5` or `12,5`) |

Also send me, as a plain list:

- **Store names and codes**, if they differ from PST, BKS and TGR
- **Staff per store**: name, role (owner, manager, cashier, inventory, kitchen), and an email address for anyone who needs the back office
- **The category order** you want on the cashier screen, plus your favorite items per store
