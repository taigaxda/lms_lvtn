import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkAdmin } from '../middleware.js'
import bcrypt from 'bcrypt'
import { use } from 'react'

const router = express.Router()
const kiemTraPassword = (password) => {
  const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.])[A-Za-z\d@$!%*?&.]{6,}$/
  if (!password) {
    return {
      isValid: false,
      message: "Vui lòng nhập mật khẩu"
    }
  }
  if (password.length < 6) {
    return {
      isValid: false,
      message: "Mật khẩu phải có ít nhất 6 ký tự"
    }
  }
  if (!passwordRegex.test(password)) {
    return {
      isValid: false,
      message: "Mật khẩu phải bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt (@$!%*?&.)"
    }
  }
  return {
    isValid: true,
    message: "Mật khẩu hợp lệ"
  }
}

router.get('/', checkAdmin, async (req, res) => {
  try {
    const users = await prisma.nguoidung.findMany()
    res.json(users)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

router.get('/search', checkAdmin, async (req, res) => {
  try {
    const { taiKhoan } = req.query

    const users = await prisma.nguoidung.findMany({
      where: taiKhoan
        ? {
          taiKhoan: {
            contains: taiKhoan,
          },
        }
        : {},
    })

    res.json(users)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

router.get('/:id', checkAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id)

    const user = await prisma.nguoidung.findUnique({
      where: { idNguoiDung: id }
    })

    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy user' })
    }

    res.json(user)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})


router.post('/', checkAdmin, async (req, res) => {
  try {
    let { hoTen, taiKhoan, matKhau, email, vaiTro } = req.body
    hoTen = hoTen ? hoTen.trim().replace(/\s+/g, ' ') : undefined
    taiKhoan = taiKhoan ? taiKhoan.trim() : undefined
    matKhau = matKhau ? matKhau.trim() : undefined
    email = email ? email.trim() : undefined
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const nameRegex = /^[a-zA-ZÀ-ỹ\s]+$/

    if (!hoTen || !taiKhoan || !matKhau || !email) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng điền đầy đủ thông tin"
      })
    }
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Email không hợp lệ"
      })
    }
    if (!nameRegex.test(hoTen)) {
      return res.status(400).json({
        success: false,
        message: "Họ tên chỉ được chứa chữ cái và khoảng trắng"
      })
    }
    const matKhauManh = kiemTraPassword(matKhau)
    if (!matKhauManh.isValid) {
      return res.status(400).json({
        success: false,
        message: matKhauManh.message
      })
    }
    const existing = await prisma.nguoidung.findUnique({
      where: { taiKhoan }
    })
    if (existing) {
      return res.status(409).json({
        success: false,
        message: "Tài khoản đã tồn tại"
      })
    }
    const matKhauHash = await bcrypt.hash(matKhau, 10)

    const newUser = await prisma.nguoidung.create({
      data: {
        hoTen,
        taiKhoan,
        matKhau: matKhauHash,
        email,
        trangThai: true,
        vaiTro
      }
    })

    res.json(newUser)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

router.put('/:id', checkAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    let { hoTen, email, trangThai, vaiTro, matKhau } = req.body
    hoTen = hoTen ? hoTen.trim().replace(/\s+/g, ' ') : undefined
    matKhau = matKhau ? matKhau.trim() : undefined
    email = email ? email.trim() : undefined
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    const nameRegex = /^[a-zA-ZÀ-ỹ\s]+$/

    if (!hoTen || !email) {
      return res.status(400).json({
        success: false,
        message: "Vui lòng điền đầy đủ thông tin"
      })
    }
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: "Email không hợp lệ"
      })
    }
    if (!nameRegex.test(hoTen)) {
      return res.status(400).json({
        success: false,
        message: "Họ tên chỉ được chứa chữ cái và khoảng trắng"
      })
    }
    if (matKhau && matKhau !== "") {
      const matKhauManh = kiemTraPassword(matKhau)
      if (!matKhauManh.isValid) {
        return res.status(400).json({
          success: false,
          message: matKhauManh.message
        })
      }
    }
    let updateObject = {
      hoTen,
      email,
      trangThai,
      vaiTro
    }

    if (matKhau && matKhau !== "") {
      const matKhauHash = await bcrypt.hash(matKhau, 10)
      updateObject.matKhau = matKhauHash
    }

    const updatedUser = await prisma.nguoidung.update({
      where: { 
        idNguoiDung: id 
      },
      data: updateObject
    })

    res.json(updatedUser)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

router.delete('/:id', checkAdmin, async (req, res) => {
  try {
    const id = parseInt(req.params.id)
    const idNguoiDungHT = req.user.idNguoiDung
    const { force } = req.query

    const user = await prisma.nguoidung.findUnique({
      where: {
        idNguoiDung: id
      }
    })
    if (!user) {
      return res.status(404).json({ message: 'User không tồn tại' })
    }
    if (user.idNguoiDung === idNguoiDungHT) {
      return res.status(403).json({
        message: 'Không thể xóa chính bản thân'
      })
    }
    const [dangKy, khoaHoc] = await Promise.all([
      prisma.dangky_khoahoc.count({
        where: {
          idNguoiDung: id
        }
      }),
      prisma.khoahoc.count({
        where: {
          idGiangVien: id
        }
      })
    ])

    const hasRelation = dangKy > 0 || khoaHoc > 0
    if (hasRelation && force !== 'true') {
      return res.status(200).json({
        success: false,
        requireConfirm: true,
        message: `User đã đăng ký ${dangKy} lớp và dạy ${khoaHoc} lớp học`,
        data: {
          soLopDangKy: dangKy,
          soKhoaHocDay: khoaHoc
        }
      })
    }
    await prisma.$transaction([
      prisma.dangky_khoahoc.deleteMany({
        where: {
          idNguoiDung: id
        }
      }),
      prisma.khoahoc.updateMany({
        where: {
          idGiangVien: id
        },
        data: {
          idGiangVien: null
        }
      }),
      prisma.nguoidung.delete({
        where: {
          idNguoiDung: id
        }
      })
    ])
    res.json({
      success: true,
      message: 'Xóa thành công'
    })

  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

router.delete('/kick/:idKhoaHoc/:idNguoiDung', checkAdmin, async (req, res) => {
  try {
    const idKhoaHoc = parseInt(req.params.idKhoaHoc)
    const idNguoiDung = parseInt(req.params.idNguoiDung)
    const dangKy = await prisma.dangky_khoahoc.findFirst({
      where: {
        idKhoaHoc,
        idNguoiDung
      }
    })
    if (!dangKy) {
      return res.status(404).json({
        success: false,
        message: "Học viên không tồn tại trong lớp"
      })
    }

    await prisma.dangky_khoahoc.delete({
      where: {
        idDangKy: dangKy.idDangKy
      }
    })

    res.json({
      success: true,
      message: "Admin đã xóa học viên khỏi lớp"
    })
  }
  catch (err) {
    res.status(500).json({ error: err.message })
  }
})

export default router