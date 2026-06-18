import { v2 as cloudinary } from 'cloudinary';
import fs from 'fs';
import dotenv from 'dotenv';

dotenv.config();

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

export const uploadToCloudinary = async (file) => {
    try {
        const originalName = file.originalname.split('.').slice(0, -1).join('.');
        const extension = file.originalname.split('.').pop().toLowerCase();

        // Kiểm tra xem có phải file PDF không
        const isPDF = extension === 'pdf';

        const result = await cloudinary.uploader.upload(file.path, {
            // "auto" sẽ tự nhận diện PDF là "image", còn Word/Excel là "raw"
            resource_type: "auto", 
            folder: "LMS_Project",
            
            // LOGIC QUAN TRỌNG TẠI ĐÂY:
            // - Nếu là PDF: Chỉ gửi tên "abc" (Cloudinary tự thêm .pdf)
            // - Nếu là file khác: Phải gửi "abc.docx" (để không bị mất đuôi)
            public_id: isPDF ? originalName : file.originalname,
            
            use_filename: true,
            unique_filename: false,
        });

        return result.secure_url;

    } catch (error) {
        console.error("Lỗi:", error);
        throw error;
    } finally {
        if (fs.existsSync(file.path)) {
            fs.unlinkSync(file.path);
        }
    }
};