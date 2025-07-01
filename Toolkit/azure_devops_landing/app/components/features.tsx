
'use client';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { 
  Terminal, 
  FileSpreadsheet, 
  CheckSquare, 
  BookOpen, 
  Shield, 
  Zap,
  Users,
  GitBranch,
  Settings,
  Download
} from 'lucide-react';

export default function Features() {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const features = [
    {
      icon: Terminal,
      title: "5 PowerShell Scripts",
      description: "Automated extraction of permissions at organization, project, repository, and pipeline levels",
      details: ["Organization-level permissions", "Project-level access control", "Repository permissions", "Pipeline security", "User group mappings"]
    },
    {
      icon: FileSpreadsheet,
      title: "Excel Permission Matrix",
      description: "Comprehensive template with multiple worksheets for complete permission documentation",
      details: ["Multi-worksheet template", "Permission inheritance mapping", "User access summary", "Compliance reporting", "Visual permission hierarchy"]
    },
    {
      icon: CheckSquare,
      title: "150+ Point Workflow Checklist",
      description: "Step-by-step checklist for new Azure DevOps organization setup and configuration",
      details: ["Organization setup steps", "Security configuration", "Project templates", "User onboarding", "Compliance verification"]
    },
    {
      icon: BookOpen,
      title: "Professional Documentation",
      description: "Complete documentation package with implementation guides and best practices",
      details: ["Installation guides", "Best practice recommendations", "Troubleshooting tips", "Security guidelines", "Maintenance procedures"]
    },
    {
      icon: Shield,
      title: "Enterprise Security",
      description: "Built with enterprise security standards and compliance requirements in mind",
      details: ["SOC 2 compliance ready", "GDPR considerations", "Audit trail support", "Role-based access", "Security best practices"]
    },
    {
      icon: Zap,
      title: "Rapid Deployment",
      description: "Get up and running quickly with pre-configured templates and automated scripts",
      details: ["Quick start guide", "Pre-configured templates", "Automated setup scripts", "Minimal configuration", "Instant results"]
    }
  ];

  return (
    <section id="features" className="section-padding bg-white">
      <div className="container-max">
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            Everything You Need in One Toolkit
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Our comprehensive solution includes all the tools, templates, and documentation 
            needed to master Azure DevOps permission management.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 50 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="group bg-white rounded-2xl p-8 shadow-lg border border-gray-200 hover:shadow-2xl hover:border-blue-300 transition-all duration-300 transform hover:-translate-y-2"
            >
              <div className="flex items-center space-x-4 mb-6">
                <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                  <feature.icon className="h-7 w-7 text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900">{feature.title}</h3>
              </div>

              <p className="text-gray-600 mb-6 leading-relaxed">
                {feature.description}
              </p>

              <div className="space-y-3">
                {feature.details.map((detail, detailIndex) => (
                  <div key={detailIndex} className="flex items-center space-x-3">
                    <div className="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0"></div>
                    <span className="text-sm text-gray-700">{detail}</span>
                  </div>
                ))}
              </div>

              <div className="mt-6 pt-6 border-t border-gray-100">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-blue-600">Ready to Use</span>
                  <Download className="h-4 w-4 text-blue-600 group-hover:translate-y-1 transition-transform" />
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        {/* Technical Specifications */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.6 }}
          className="mt-16 bg-gray-50 rounded-2xl p-8"
        >
          <h3 className="text-2xl font-bold text-gray-900 mb-8 text-center">Technical Specifications</h3>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Terminal className="h-8 w-8 text-blue-600" />
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">PowerShell 5.1+</h4>
              <p className="text-sm text-gray-600">Compatible with Windows PowerShell and PowerShell Core</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <FileSpreadsheet className="h-8 w-8 text-green-600" />
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">Excel 2016+</h4>
              <p className="text-sm text-gray-600">Works with Microsoft Excel and Excel Online</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-purple-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Shield className="h-8 w-8 text-purple-600" />
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">Azure DevOps</h4>
              <p className="text-sm text-gray-600">Server 2019+ and Azure DevOps Services</p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <Users className="h-8 w-8 text-orange-600" />
              </div>
              <h4 className="font-semibold text-gray-900 mb-2">Multi-User</h4>
              <p className="text-sm text-gray-600">Supports organizations of any size</p>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
