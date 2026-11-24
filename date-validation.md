# Independent date validation

The corrected order and ship dates match the published reference for **all 9,994 transaction lines and all 5,009 orders**. This check used the 2014–2017 US edition. Superstore is a fictitious retailer represented in a public sample dataset.

## Evidence

A published copy of the Orders worksheet includes the original row ID, order ID, order date and ship date. Its order date and ship date use US month/day/year. I read all 9,994 row IDs, parsed both dates, and matched the row ID against the original upload's one-based CSV data-record position. All 9,994 order IDs matched in that order. I then compared both reference dates with each corrected date, independently of the interval test. Both the delivered flat transaction file and the join of delivered order lines to orders matched the reference fingerprint below. [Matching worksheet](https://www.scribd.com/document/584053243/Sample-Superstore) · [Public dataset viewer](https://huggingface.co/datasets/An-j96/SuperstoreData) · [Tableau sample provenance](https://public.tableau.com/app/resources/sample-data)

| Check | Result |
|---|---:|
| Original row IDs compared | 1–9,994 |
| Distinct order IDs compared | 5,009 |
| Mismatching row/order pairs | 0 |
| Mismatching corrected order dates | 0 |
| Mismatching corrected ship dates | 0 |
| Orders with a corrected order date | 1,836 |
| Orders with a corrected ship date | 1,806 |
| Orders with either date corrected | 2,494 |
| Lines with either date corrected | 4,929 |

The upload already had ISO-looking strings. To undo the earlier day/month exchange, each valid date whose day was at most 12 had its month and day swapped. Equal month/day pairs stayed the same. Values with a day above 12 stayed the same. Corrected order dates range from January 3, 2014 to December 30, 2017. Ship dates range from January 7, 2014 to January 5, 2018. All shipping intervals are 0–7 days.

For order `CA-2016-138688`, the upload shows December 6, 2016 with a June 16 shipment. The reference gives June 12, 2016 and June 16, 2016. The otherwise identical lines for `US-2014-150119` carry distinct published row IDs **3406** and **3407**. Both are retained.

## Reproduce the reference check

The expected SHA-256 below comes from the separately published row IDs, order IDs and parsed dates. Run the following Python code from the extracted package directory. It uses the standard library.

```python
import csv
import hashlib

with open("data/transactions.csv", encoding="utf-8-sig", newline="") as source:
    rows = sorted(csv.DictReader(source), key=lambda row: int(row["line_item_id"]))

expected = "f9f032e7727d125a66a4cda899cfd7fc474cec8d2733575308810148534b5fa9"
digest = hashlib.sha256()
for row in rows:
    fields = [row[key] for key in ("line_item_id", "order_id", "order_date", "ship_date")]
    digest.update(("\t".join(fields) + "\n").encode("utf-8"))
assert len(rows) == 9994 and digest.hexdigest() == expected
print("All 9,994 order IDs and date pairs match the external reference.")
```
