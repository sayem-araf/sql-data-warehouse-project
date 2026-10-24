import csv
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from prepare_sources import prepare
import shutil

FIXTURES=Path(__file__).parent/'fixtures'

class SourcePreparationTests(unittest.TestCase):
    def test_unicode_quotes_and_uppercase_filenames(self):
        with tempfile.TemporaryDirectory() as directory:
            source=Path(directory)/'source'; destination=Path(directory)/'staged'
            shutil.copytree(FIXTURES,source)
            path=source/'source_crm/cust_info.csv'
            with path.open(newline='') as stream: rows=list(csv.reader(stream))
            rows[1][2]='Åsa, "Demo"'
            with path.open('w',newline='',encoding='utf-8-sig') as stream: csv.writer(stream).writerows(rows)
            erp=source/'source_erp/cust_az12.csv'; erp.rename(erp.with_name('CUST_AZ12.csv'))
            prepare(source,destination)
            with (destination/'source_crm/cust_info.csv').open(encoding='utf-16',newline='') as stream:
                actual=list(csv.reader(stream))
            self.assertEqual(actual[1][2],'Åsa, "Demo"')

    def test_bad_header_does_not_overwrite_staged_files(self):
        with tempfile.TemporaryDirectory() as directory:
            source=Path(directory)/'source'; destination=Path(directory)/'staged'
            shutil.copytree(FIXTURES,source);destination.mkdir()
            sentinel=destination/'sentinel';sentinel.write_text('preserve')
            (source/'source_crm/cust_info.csv').write_text('wrong,header\n1,2\n')
            with self.assertRaises(ValueError):prepare(source,destination)
            self.assertEqual(list(destination.iterdir()),[sentinel])

    def test_ambiguous_filename_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            source=Path(directory)/'source';shutil.copytree(FIXTURES,source)
            shutil.copyfile(source/'source_crm/cust_info.csv',source/'cust_info.csv')
            with self.assertRaises(ValueError):prepare(source,Path(directory)/'destination')

if __name__=='__main__':unittest.main()
