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

        // ✅ Xác định resource_type dựa trên extension
        let resourceType = "auto";
        let publicId = file.originalname;

        // ✅ PDF và các file tài liệu nên dùng "raw"
        const documentExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'zip', 'rar', '7z'];
        const imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'webp'];
        const videoExtensions = ['mp4', 'mov', 'avi', 'mkv'];

        if (documentExtensions.includes(extension)) {
            resourceType = "raw";  // ✅ Dùng raw cho tài liệu
            // ✅ Giữ nguyên tên file có đuôi
            publicId = file.originalname;
        } else if (imageExtensions.includes(extension)) {
            resourceType = "image";
            publicId = originalName;  // Cloudinary tự thêm đuôi cho ảnh
        } else if (videoExtensions.includes(extension)) {
            resourceType = "video";
            publicId = originalName;
        }

        console.log(`📤 Uploading ${file.originalname} as ${resourceType}`);

        const result = await cloudinary.uploader.upload(file.path, {
            resource_type: resourceType,
            folder: "LMS_Project",
            public_id: publicId,
            use_filename: true,
            unique_filename: false,
            // access_mode: "public",   // ✅ Thêm dòng này
            type: "upload",
            // ✅ Thêm flag để cho phép tải file
            // flags: resourceType === "raw" ? "attachment" : undefined,
        });

        console.log(`✅ Uploaded: ${result.secure_url}`);
        return result.secure_url;

    } catch (error) {
        console.error("❌ Lỗi upload:", error);
        throw error;
    } finally {
        if (fs.existsSync(file.path)) {
            fs.unlinkSync(file.path);
        }
    }
};