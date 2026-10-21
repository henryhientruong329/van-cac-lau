import {adminCall} from './supabase';
export const comments=(book:string|null,parent:string|null,offset=0,category='')=>adminCall('vcl_comment_list',{p_book:book,p_parent:parent,p_offset:offset,p_category:category});
export const postComment=(body:string,book:string|null,parent:string|null,title='',category='Cảm nhận',spoiler=false)=>adminCall('vcl_comment_post',{p_body:body,p_book:book,p_parent:parent,p_title:title,p_category:category,p_spoiler:spoiler});
export const deleteComment=(id:string)=>adminCall('vcl_comment_delete',{p_id:id});
export const reportComment=(id:string,reason:string)=>adminCall('vcl_comment_report',{p_id:id,p_reason:reason});
export const rateBook=(id:string,stars:number)=>adminCall('vcl_rate_book',{p_book:id,p_stars:stars});
export const removeRating=(id:string)=>adminCall('vcl_rating_remove',{p_book:id});
export const bookRatings=(id:string)=>adminCall('vcl_book_ratings',{p_book:id});
export async function ratingSummaries(ids:string[]){const result:Record<string,{average:number|null;count:number}>={};for(let i=0;i<ids.length;i+=100){const rows=await adminCall('vcl_rating_summary',{p_ids:ids.slice(i,i+100)});for(const row of rows)result[row.book_id]={average:row.average,count:row.count}}return result}
