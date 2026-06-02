import express from 'express'
import { prisma } from './prisma/client.js'

const router = express.Router()

router.get('/', async (req, res) => {
    return res.json({ message: "API is working" })
})

export default router