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
    if (!file || !file.path) {
        throw new Error("Dữ liệu file không hợp lệ");
    }

    try {
        // const result = await cloudinary.uploader.upload(file.path, {
        //     resource_type: "auto",
        //     folder: "LMS_Project",
        //     public_id: file.originalname.split('.')[0],
        //     use_filename: true,
        //     unique_filename: true,
        // });

        // console.log(`✅ Cloudinary Upload Success: ${result.secure_url}`);

        // return result.secure_url;
        // Tách lấy tên file không bao gồm đuôi để làm public_id
        // Lấy tên file gốc bỏ đuôi
        const originalName = file.originalname.split('.').slice(0, -1).join('.');
        // Lấy đuôi file (pdf, docx, ...)
        const extension = file.originalname.split('.').pop();

        const result = await cloudinary.uploader.upload(file.path, {
            resource_type: "auto",
            folder: "LMS_Project",
            // Quan trọng: Kết hợp tên gốc + đuôi để Cloudinary tạo Link có đuôi
            public_id: `${originalName}.${extension}`, 
            use_filename: true,
            unique_filename: false, // Để false nếu bạn muốn link đẹp cố định
        });

        return result.secure_url;

    } catch (error) {
        console.error("❌ Cloudinary Error:", error.message);
        throw error;
    } finally {
        // Xóa file tạm trong thư mục uploads/ sau khi upload xong
        if (fs.existsSync(file.path)) {
            try {
                fs.unlinkSync(file.path);
                console.log("Đã dọn dẹp file tạm.");
            } catch (err) {
                console.error("Lỗi xóa file tạm:", err);
            }
        }
    }
};