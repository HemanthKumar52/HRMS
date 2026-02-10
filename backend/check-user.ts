
import { PrismaClient } from '@prisma/client'
import * as bcrypt from 'bcrypt'

const prisma = new PrismaClient()

async function main() {
    try {
        const user = await prisma.user.findUnique({
            where: { email: 'employee@acme.com' },
        })

        if (user) {
            console.log('User found.')
            const match = await bcrypt.compare('password123', user.passwordHash)
            console.log('Password match:', match)
            console.log('Is Active:', user.isActive)
        } else {
            console.log('User NOT found')
        }

    } catch (e) {
        console.error('Error checking user:', e)
    } finally {
        await prisma.$disconnect()
    }
}

main()
