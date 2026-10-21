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
/** Keep authored breaks; only add visual paragraph breaks to long unformatted summaries. */
export function summaryBlocks(value:string):string[]{
 let text=normalizeVietnamese(value).replace(/\r\n?/g,'\n').trim();
 if(!text)return [];
 const prefix=text.match(/^(?:\*\*[^*]+\*\*[ \t]*){1,2}/u)?.[0];
 if(prefix)text=prefix.replace(/(\*\*[^*]+\*\*)[ \t]*/gu,'$1\n\n')+text.slice(prefix.length);
 return text.split(/\n+/u).map(s=>s.trim()).filter(Boolean).flatMap(block=>{
  if(block.length<=360||/^\*\*[^*]+\*\*$/u.test(block))return [block];
  const result:string[]=[];let start=0;
  for(let i=0;i<block.length;i++)if(/[.!?…]/u.test(block[i])&&/\s/u.test(block[i+1]||'')&&i-start>=190){result.push(block.slice(start,i+1));start=i+1;while(/\s/u.test(block[start]||'')&&start<block.length)start++}
  if(start<block.length)result.push(block.slice(start));return result;
 });
}
