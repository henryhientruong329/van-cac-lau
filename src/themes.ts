export type ThemeId='auto'|'romance'|'wuxia'|'scifi';
export const themes=[
 {id:'romance' as const,name:'Hồng Thư',genre:'Tình cảm',tag:'LOVE, IN EVERY LINE',symbol:'❀',headline:'Một lần gặp gỡ.\nMột đời thương nhớ.',description:'Giấy hồng phấn, sắc rượu vang và những đường nét mềm mại như một lá thư tay.',color:'#98576b',chapter:'Chương 1 · Cuộc gặp gỡ',outline:'**Một cuộc gặp gỡ**\n[Giới thiệu hai nhân vật và hoàn cảnh họ gặp nhau.]\n\n**Một điều chưa nói**\n[Mâu thuẫn tình cảm hoặc bí mật ngăn cách họ.]\n\n**Một lựa chọn của trái tim**\n[Câu hỏi gợi mở khiến độc giả muốn đọc tiếp.]'},
 {id:'wuxia' as const,name:'Mặc Kiếm',genre:'Kiếm hiệp Trung Hoa',tag:'INK, HONOR & DESTINY',symbol:'劍',headline:'Một nét mực.\nVạn dặm giang hồ.',description:'Giấy cổ, núi thủy mặc và dấu son đỏ; mở ra không khí giang hồ đậm chất phương Đông.',color:'#504d42',chapter:'Hồi 1 · Gió nổi giang hồ',outline:'**Giang hồ dậy sóng**\n[Bối cảnh thời đại và biến cố mở đầu.]\n\n**Người mang kiếm**\n[Nhân vật chính, thân thế và điều người ấy theo đuổi.]\n\n**Ân oán chưa tàn**\n[Mâu thuẫn, bí mật hoặc lời thề mở ra hành trình.]'},
 {id:'scifi' as const,name:'Tinh Vân',genre:'Khoa học viễn tưởng',tag:'BEYOND THE KNOWN',symbol:'✧',headline:'Qua một trang sách.\nChạm một thiên hà.',description:'Bầu trời xanh thẳm, quỹ đạo ánh sáng và điểm nhấn cyan cho những chuyến đi vượt giới hạn.',color:'#143b59',chapter:'Chương 1 · Tín hiệu đầu tiên',outline:'**Thế giới tương lai**\n[Thời điểm, không gian và quy luật công nghệ.]\n\n**Tín hiệu bất thường**\n[Khám phá hoặc sự kiện làm thay đổi mọi thứ.]\n\n**Giới hạn cuối cùng**\n[Thử thách và câu hỏi về con người trong thế giới ấy.]'}
];
export function bookTheme(book:{template?:string;genre?:string}):Exclude<ThemeId,'auto'>|null{
 if(themes.some(t=>t.id===book.template))return book.template as Exclude<ThemeId,'auto'>;
 const g=(book.genre||'').toLocaleLowerCase('vi');
 if(/kiếm hiệp|tiên hiệp|huyền huyễn/.test(g))return 'wuxia';
 if(/viễn tưởng|khoa học/.test(g))return 'scifi';
 if(/tình cảm|ngôn tình|lãng mạn/.test(g))return 'romance';
 return null;
}
