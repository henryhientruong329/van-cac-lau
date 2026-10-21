/** Normalize rendering text without rewriting the author's spelling. */
export function normalizeVietnamese(value:string):string {
 return value.replace(/[\u200b\ufeff]/g,'')
  .replace(/(\p{L}\p{M}*)[ \t]+(?=[\u0300\u0301\u0303\u0309\u0323\u0302\u0306\u031b])/gu,'$1')
  .normalize('NFC');
}
export function textPages(value:string,wordsPerPage=140):string[]{
 const words=normalizeVietnamese(value).match(/\S+\s*/gu)||[];
 const pages:string[]=[];
 for(let k=0;k<Math.max(1,words.length);k+=wordsPerPage)pages.push(words.slice(k,k+wordsPerPage).join(''));
 return pages;
}
export function inlineParts(value:string):{text:string;bold:boolean}[]{
 return normalizeVietnamese(value).split(/(\*\*[^*]+\*\*)/gu).filter(Boolean).map(text=>({text:text.startsWith('**')&&text.endsWith('**')?text.slice(2,-2):text,bold:text.startsWith('**')&&text.endsWith('**')}));
}
