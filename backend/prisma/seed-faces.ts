import { PrismaClient, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();

async function main() {
  // Get the existing organization
  const org = await prisma.organization.findFirst();
  if (!org) {
    console.error('No organization found. Run the main seed first.');
    process.exit(1);
  }
  console.log(`Using organization: ${org.name} (${org.id})`);

  const passwordHash = await bcrypt.hash('password123', 10);

  // Path to registered faces
  const facesDir = path.join(__dirname, '..', '..', 'blink_project', 'registered_faces');

  // Read face photos as base64
  function readFacePhoto(filename: string): string | null {
    const filepath = path.join(facesDir, filename);
    if (!fs.existsSync(filepath)) {
      console.warn(`Face photo not found: ${filepath}`);
      return null;
    }
    const buffer = fs.readFileSync(filepath);
    return buffer.toString('base64');
  }

  const users = [
    {
      email: 'hk@acme.com',
      firstName: 'HK',
      lastName: '',
      role: Role.MANAGER,
      department: 'Engineering',
      designation: 'Engineering Manager',
      faceFile: 'HK.jpg',
    },
    {
      email: 'anish@acme.com',
      firstName: 'anish',
      lastName: '',
      role: Role.EMPLOYEE,
      department: 'Engineering',
      designation: 'Software Engineer',
      faceFile: 'anish.jpg',
    },
    {
      email: 'suriya@acme.com',
      firstName: 'suriya',
      lastName: '',
      role: Role.HR_ADMIN,
      department: 'Human Resources',
      designation: 'HR Admin',
      faceFile: 'suriya.jpg',
    },
  ];

  for (const u of users) {
    const facePhoto = readFacePhoto(u.faceFile);

    const user = await prisma.user.upsert({
      where: { email: u.email },
      update: {
        role: u.role,
        facePhoto: facePhoto,
        department: u.department,
        designation: u.designation,
      },
      create: {
        email: u.email,
        passwordHash,
        firstName: u.firstName,
        lastName: u.lastName,
        role: u.role,
        organizationId: org.id,
        department: u.department,
        designation: u.designation,
        facePhoto: facePhoto,
      },
    });

    console.log(`✓ ${u.firstName} — ${u.role} (${u.email}) — face: ${facePhoto ? 'loaded' : 'missing'}`);
  }

  console.log('\nDone! All 3 users created/updated.');
  console.log('Login credentials: email + password123');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
