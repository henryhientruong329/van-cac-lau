import {inlineParts,summaryBlocks} from './text';
export default function Summary({text}:{text:string}){return <div className="synopsis" aria-label="Tóm tắt tác phẩm">{summaryBlocks(text).map((block,i)=><p key={i} className={/^\*\*[^*]+\*\*$/u.test(block)?'synopsis-lead':''}>{inlineParts(block).map((p,j)=>p.bold?<strong key={j}>{p.text}</strong>:<span key={j}>{p.text}</span>)}</p>)}</div>}
