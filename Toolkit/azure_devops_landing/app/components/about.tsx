
'use client';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { 
  Award, 
  Users, 
  Shield, 
  Zap, 
  CheckCircle,
  Star,
  Building,
  Globe
} from 'lucide-react';
import Image from 'next/image';

export default function About() {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const credentials = [
    {
      icon: Award,
      title: "Microsoft Certified",
      description: "Azure DevOps Engineer Expert and Azure Solutions Architect certifications"
    },
    {
      icon: Users,
      title: "10+ Years Experience",
      description: "Extensive experience in enterprise Azure DevOps implementations"
    },
    {
      icon: Building,
      title: "Fortune 500 Clients",
      description: "Trusted by major corporations for their DevOps transformation"
    },
    {
      icon: Globe,
      title: "Global Reach",
      description: "Supporting organizations worldwide with Azure DevOps solutions"
    }
  ];

  const testimonials = [
    {
      name: "Sarah Johnson",
      role: "IT Director",
      company: "TechCorp Solutions",
      content: "This toolkit saved us weeks of work. The PowerShell scripts are incredibly well-documented and the Excel templates are professional-grade.",
      rating: 5
    },
    {
      name: "Michael Chen",
      role: "DevOps Manager",
      company: "Global Manufacturing Inc.",
      content: "Finally, a comprehensive solution for Azure DevOps permissions. The 150-point checklist ensured we didn't miss anything during our org setup.",
      rating: 5
    },
    {
      name: "Lisa Rodriguez",
      role: "Security Architect",
      company: "Financial Services Ltd.",
      content: "The permission matrix template is exactly what we needed for our compliance audits. Professional quality and enterprise-ready.",
      rating: 5
    }
  ];

  const stats = [
    { number: "500+", label: "Organizations Helped" },
    { number: "10,000+", label: "Hours Saved" },
    { number: "99.9%", label: "Customer Satisfaction" },
    { number: "24/7", label: "Support Available" }
  ];

  return (
    <section id="about" className="section-padding bg-white">
      <div className="container-max">
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            Trusted by IT Professionals Worldwide
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Our Azure DevOps Permission Matrix Toolkit is developed by certified experts 
            with extensive experience in enterprise DevOps implementations.
          </p>
        </motion.div>

        {/* Credentials */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8 mb-16">
          {credentials.map((credential, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 50 }}
              animate={inView ? { opacity: 1, y: 0 } : {}}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="text-center group"
            >
              <div className="w-20 h-20 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:scale-110 transition-transform duration-300">
                <credential.icon className="h-10 w-10 text-white" />
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">{credential.title}</h3>
              <p className="text-gray-600 text-sm">{credential.description}</p>
            </motion.div>
          ))}
        </div>

        {/* About Content */}
        <div className="grid lg:grid-cols-2 gap-16 items-center mb-16">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.4 }}
          >
            <h3 className="text-3xl font-bold text-gray-900 mb-6">
              Built by Azure DevOps Experts
            </h3>
            <p className="text-lg text-gray-600 mb-6 leading-relaxed">
              Our team consists of Microsoft-certified Azure DevOps engineers with over a decade 
              of experience implementing enterprise-scale DevOps solutions. We've seen the challenges 
              firsthand and built this toolkit to solve the most common pain points.
            </p>
            
            <div className="space-y-4 mb-8">
              <div className="flex items-center space-x-3">
                <CheckCircle className="h-6 w-6 text-green-500 flex-shrink-0" />
                <span className="text-gray-700">Microsoft Azure DevOps Engineer Expert certified</span>
              </div>
              <div className="flex items-center space-x-3">
                <CheckCircle className="h-6 w-6 text-green-500 flex-shrink-0" />
                <span className="text-gray-700">500+ successful Azure DevOps implementations</span>
              </div>
              <div className="flex items-center space-x-3">
                <CheckCircle className="h-6 w-6 text-green-500 flex-shrink-0" />
                <span className="text-gray-700">Trusted by Fortune 500 companies</span>
              </div>
              <div className="flex items-center space-x-3">
                <CheckCircle className="h-6 w-6 text-green-500 flex-shrink-0" />
                <span className="text-gray-700">Continuous updates based on latest Azure DevOps features</span>
              </div>
            </div>

            <div className="bg-blue-50 rounded-xl p-6 border border-blue-200">
              <h4 className="font-semibold text-blue-900 mb-2">Our Mission</h4>
              <p className="text-blue-800">
                To empower IT administrators with professional-grade tools that simplify 
                Azure DevOps permission management and ensure enterprise security standards.
              </p>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 50 }}
            animate={inView ? { opacity: 1, x: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.6 }}
            className="relative"
          >
            <div className="relative aspect-square bg-gradient-to-br from-blue-100 to-purple-100 rounded-2xl overflow-hidden">
              <Image
                src="https://i.ytimg.com/vi/ahZyANt5fIQ/maxresdefault.jpg"
                alt="Azure DevOps Experts Team"
                fill
                className="object-cover"
              />
            </div>
            
            {/* Floating Stats */}
            <div className="absolute -bottom-6 -left-6 bg-white rounded-xl p-4 shadow-xl border border-gray-200">
              <div className="text-2xl font-bold text-blue-600">10+</div>
              <div className="text-sm text-gray-600">Years Experience</div>
            </div>
            
            <div className="absolute -top-6 -right-6 bg-white rounded-xl p-4 shadow-xl border border-gray-200">
              <div className="text-2xl font-bold text-green-600">500+</div>
              <div className="text-sm text-gray-600">Projects Completed</div>
            </div>
          </motion.div>
        </div>

        {/* Statistics */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 0.8 }}
          className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-2xl p-8 text-white mb-16"
        >
          <h3 className="text-2xl font-bold text-center mb-8">Our Impact</h3>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-8">
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-4xl font-bold mb-2">{stat.number}</div>
                <div className="text-blue-100">{stat.label}</div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Testimonials */}
        <motion.div
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8, delay: 1 }}
        >
          <h3 className="text-3xl font-bold text-gray-900 mb-12 text-center">
            What Our Customers Say
          </h3>

          <div className="grid lg:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                animate={inView ? { opacity: 1, y: 0 } : {}}
                transition={{ duration: 0.6, delay: 1.2 + index * 0.1 }}
                className="bg-gray-50 rounded-2xl p-6 border border-gray-200"
              >
                <div className="flex items-center space-x-1 mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="h-5 w-5 text-yellow-400 fill-current" />
                  ))}
                </div>
                
                <p className="text-gray-700 mb-6 italic">"{testimonial.content}"</p>
                
                <div>
                  <div className="font-semibold text-gray-900">{testimonial.name}</div>
                  <div className="text-sm text-gray-600">{testimonial.role}</div>
                  <div className="text-sm text-blue-600">{testimonial.company}</div>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  );
}
