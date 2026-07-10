import OpenAI from "openai";

const openai = new OpenAI({
    apiKey: process.env.DEEPSEEK_API_KEY,
    baseURL: "https://openrouter.ai/api/v1"
});

function cleanResponse(text) {
    if (!text) return text;
    
    let cleaned = text
        .replace(/User Safety: safe\n?/g, '')      
        .replace(/^User Safety: safe\s*/gm, '')    
        .replace(/```json\n?/g, '')                
        .replace(/```\n?/g, '')                    
        .trim();
    
    return cleaned;
}

async function callOpenRouter(messages) {
    try {
        const completion = await openai.chat.completions.create({
            model: "openrouter/free",
            messages: messages,
            temperature: 0.7,
            max_tokens: 1000,
        });

        let content = completion.choices[0].message.content || "";
        
        content = cleanResponse(content);
        
        return content;
    } catch (error) {
        console.error("Lỗi OpenRouter:", error);
        throw error;
    }
}

function extractJSON(text) {
    if (!text) return null;
    
    let cleaned = cleanResponse(text);
    
    const jsonMatch = cleaned.match(/(\{[\s\S]*\}|\[[\s\S]*\])/);
    
    if (jsonMatch) {
        try {
            return JSON.parse(jsonMatch[0]);
        } catch (e) {
            console.error('Parse JSON lỗi:', e.message);
            return null;
        }
    }
    return null;
}

export async function askAI(question, context) {
    try {
        const messages = [
            {
                role: "system",
                content: `Bạn là trợ lý AI trong hệ thống học tập LMS.
                
                QUY TẮC:
                1. CHỈ trả lời câu hỏi về học tập
                2. TỪ CHỐI câu hỏi không liên quan
                3. Trả lời bằng tiếng Việt, thân thiện
                
                DỮ LIỆU HIỆN TẠI:
                ${context}`
            },
            {
                role: "user",
                content: question
            }
        ];

        const response = await callOpenRouter(messages);
        return response;

    } catch (error) {
        console.error("Lỗi AI:", error);
        return "Xin lỗi, tôi đang gặp sự cố. Vui lòng thử lại sau! 🙏";
    }
}

export async function getDailyTasks(studentData) {
    try {
        const messages = [
            {
                role: "system",
                content: "Bạn là trợ lý học tập, đề xuất công việc cần làm."
            },
            {
                role: "user",
                content: `
                DỮ LIỆU HỌC VIÊN:
                - Bài học chưa hoàn thành: ${studentData.baiHocChuaHoc}
                - Bài tập chưa nộp: ${studentData.baiTapChuaNop}
                - Quiz chưa làm: ${studentData.quizChuaLam}
                - Thông báo mới: ${studentData.thongBaoMoi}

                Đề xuất 3-5 công việc ưu tiên nhất hôm nay.
                `
            }
        ];

        const response = await callOpenRouter(messages);
        return response;

    } catch (error) {
        console.error("Lỗi đề xuất:", error);
        return "Không thể đề xuất công việc hôm nay.";
    }
}

export async function getSuggestedQuestions(context) {
    try {
        const messages = [
            {
                role: "system",
                content: `Bạn là trợ lý AI. Tạo 5 câu hỏi gợi ý dựa trên dữ liệu học viên.
                
                YÊU CẦU:
                - Câu hỏi cụ thể, dưới 50 ký tự
                - CHỈ TRẢ VỀ JSON: [{"question": "câu hỏi 1"}, {"question": "câu hỏi 2"}]
                - KHÔNG CÓ GÌ KHÁC NGOÀI JSON`
            },
            {
                role: "user",
                content: `DỮ LIỆU:\n${context}`
            }
        ];

        const response = await callOpenRouter(messages);
        
        const questions = extractJSON(response);
        
        if (questions && Array.isArray(questions) && questions.length > 0) {
            return questions;
        }
        
        return [
            { question: 'Hôm nay có gì cần lưu ý?' },
            { question: 'Deadline nào sắp tới?' },
            { question: 'Nên học bài nào trước?' },
            { question: 'Có thông báo mới nào không?' },
            { question: 'Hôm nay nên làm gì?' }
        ];

    } catch (error) {
        console.error("Lỗi:", error);
        return [
            { question: 'Hôm nay có gì cần lưu ý?' },
            { question: 'Deadline nào sắp tới?' },
            { question: 'Nên học bài nào trước?' },
            { question: 'Có thông báo mới nào không?' },
            { question: 'Hôm nay nên làm gì?' }
        ];
    }
}