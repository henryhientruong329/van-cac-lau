import {test} from 'node:test';import assert from 'node:assert/strict';
import {normalizeVietnamese,textPages,inlineParts} from '../src/text.ts';
test('Vietnamese NFD marks are composed without changing spelling',()=>{const s='Chương 1: Người không nên sống. Đứa trẻ ấy đáng lẽ phải chết trước khi trời sáng. Thanh Dao biết điều đó. Giờ Mão, ngày mười bảy tháng Chạp. Chết do núi lở.';assert.equal(normalizeVietnamese(s.normalize('NFD')),s)});
test('remove zero-width paste artifacts and repair spaces before tone marks',()=>assert.equal(normalizeVietnamese('chê \u0301t\u200b'), 'chết'));
test('pagination preserves all paragraphs and never strands a combining mark',()=>{const s=('Nàng đọc lại bốn chữ cuối.\n\nKhông còn thân nhân.\n\n').repeat(70);const pages=textPages(s.normalize('NFD'));assert.ok(pages.length>1);assert.equal(pages.join(''),s);assert.ok(pages.every(p=>!/^\p{M}/u.test(p)))});
test('bold markers render as strong text, plain text remains literal',()=>{assert.deepEqual(inlineParts('**A Ninh. Bảy tuổi.**'),[{text:'A Ninh. Bảy tuổi.',bold:true}]);assert.deepEqual(inlineParts('<script>x</script>'),[{text:'<script>x</script>',bold:false}])});
test('empty chapter has one stable page and ordinary spacing is unchanged',()=>{assert.deepEqual(textPages(''),['']);assert.equal(normalizeVietnamese('không  còn thân nhân'), 'không  còn thân nhân')});
