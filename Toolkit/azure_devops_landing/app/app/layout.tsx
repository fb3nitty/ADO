
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Azure DevOps Permission Matrix Toolkit - Professional IT Solution',
  description: 'Comprehensive toolkit for Azure DevOps permission management. Includes PowerShell scripts, Excel templates, and workflow checklists for IT administrators.',
  keywords: 'Azure DevOps, permissions, PowerShell, IT administration, enterprise toolkit',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  )
}
