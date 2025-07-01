
'use client';

import { motion } from 'framer-motion';
import { useInView } from 'react-intersection-observer';
import { 
  Check, 
  Star, 
  Download, 
  Mail, 
  Phone, 
  MessageCircle,
  Shield,
  Zap,
  Users,
  HeadphonesIcon
} from 'lucide-react';

export default function Pricing() {
  const [ref, inView] = useInView({
    triggerOnce: true,
    threshold: 0.1,
  });

  const features = [
    "5 PowerShell Scripts for Permission Extraction",
    "Comprehensive Excel Permission Matrix Template",
    "150+ Point Workflow Checklist",
    "Professional Documentation Package",
    "Implementation Best Practices Guide",
    "Troubleshooting and Support Documentation",
    "Regular Updates and Improvements",
    "Email Support for 90 Days",
    "Enterprise License (Unlimited Use)",
    "Money-Back Guarantee"
  ];

  const contactMethods = [
    {
      icon: Mail,
      title: "Email Us",
      description: "Get detailed information and custom quotes",
      contact: "sales@azuredevopstoolkit.com",
      action: "Send Email"
    },
    {
      icon: Phone,
      title: "Call Us",
      description: "Speak directly with our solutions team",
      contact: "+1 (555) 123-4567",
      action: "Call Now"
    },
    {
      icon: MessageCircle,
      title: "Live Chat",
      description: "Chat with us for immediate assistance",
      contact: "Available 9 AM - 6 PM EST",
      action: "Start Chat"
    }
  ];

  return (
    <section id="pricing" className="section-padding bg-gradient-to-br from-gray-50 to-blue-50">
      <div className="container-max">
        <motion.div
          ref={ref}
          initial={{ opacity: 0, y: 50 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.8 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
            Professional Toolkit Pricing
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Get the complete Azure DevOps Permission Matrix Toolkit with everything you need 
            to streamline your permission management process.
          </p>
        </motion.div>

        <div className="max-w-4xl mx-auto">
          {/* Main Pricing Card */}
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="relative bg-white rounded-3xl shadow-2xl border-2 border-blue-200 overflow-hidden"
          >
            {/* Popular Badge */}
            <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
              <div className="bg-gradient-to-r from-blue-600 to-purple-600 text-white px-8 py-2 rounded-full text-sm font-semibold flex items-center space-x-2">
                <Star className="h-4 w-4" />
                <span>Professional Solution</span>
              </div>
            </div>

            <div className="p-12">
              <div className="text-center mb-12">
                <h3 className="text-3xl font-bold text-gray-900 mb-4">
                  Azure DevOps Permission Matrix Toolkit
                </h3>
                <div className="flex items-center justify-center space-x-4 mb-6">
                  <div className="text-6xl font-bold text-gray-900">$497</div>
                  <div className="text-left">
                    <div className="text-gray-500 line-through text-xl">$997</div>
                    <div className="text-green-600 font-semibold">50% Launch Discount</div>
                  </div>
                </div>
                <p className="text-lg text-gray-600">
                  One-time purchase • Lifetime access • Enterprise license
                </p>
              </div>

              <div className="grid lg:grid-cols-2 gap-12">
                {/* Features List */}
                <div>
                  <h4 className="text-xl font-bold text-gray-900 mb-6">What's Included:</h4>
                  <div className="space-y-4">
                    {features.map((feature, index) => (
                      <motion.div
                        key={index}
                        initial={{ opacity: 0, x: -20 }}
                        animate={inView ? { opacity: 1, x: 0 } : {}}
                        transition={{ duration: 0.5, delay: 0.4 + index * 0.05 }}
                        className="flex items-start space-x-3"
                      >
                        <div className="w-6 h-6 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5">
                          <Check className="h-4 w-4 text-green-600" />
                        </div>
                        <span className="text-gray-700">{feature}</span>
                      </motion.div>
                    ))}
                  </div>
                </div>

                {/* Value Proposition */}
                <div>
                  <h4 className="text-xl font-bold text-gray-900 mb-6">Why Choose Our Toolkit:</h4>
                  
                  <div className="space-y-6">
                    <div className="flex items-start space-x-4">
                      <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Zap className="h-6 w-6 text-blue-600" />
                      </div>
                      <div>
                        <h5 className="font-semibold text-gray-900 mb-1">Immediate ROI</h5>
                        <p className="text-gray-600 text-sm">Save 95% of time on permission audits - toolkit pays for itself in first use</p>
                      </div>
                    </div>

                    <div className="flex items-start space-x-4">
                      <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Shield className="h-6 w-6 text-green-600" />
                      </div>
                      <div>
                        <h5 className="font-semibold text-gray-900 mb-1">Enterprise Grade</h5>
                        <p className="text-gray-600 text-sm">Professional documentation and templates used by Fortune 500 companies</p>
                      </div>
                    </div>

                    <div className="flex items-start space-x-4">
                      <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <Users className="h-6 w-6 text-purple-600" />
                      </div>
                      <div>
                        <h5 className="font-semibold text-gray-900 mb-1">Unlimited Use</h5>
                        <p className="text-gray-600 text-sm">Enterprise license covers unlimited organizations and projects</p>
                      </div>
                    </div>

                    <div className="flex items-start space-x-4">
                      <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        <HeadphonesIcon className="h-6 w-6 text-orange-600" />
                      </div>
                      <div>
                        <h5 className="font-semibold text-gray-900 mb-1">Expert Support</h5>
                        <p className="text-gray-600 text-sm">90 days of email support plus comprehensive documentation</p>
                      </div>
                    </div>
                  </div>

                  <div className="mt-8 p-4 bg-green-50 rounded-lg border border-green-200">
                    <div className="flex items-center space-x-2 mb-2">
                      <Shield className="h-5 w-5 text-green-600" />
                      <span className="font-semibold text-green-800">30-Day Money-Back Guarantee</span>
                    </div>
                    <p className="text-sm text-green-700">
                      Not satisfied? Get a full refund within 30 days, no questions asked.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>

          {/* Contact Methods */}
          <motion.div
            initial={{ opacity: 0, y: 50 }}
            animate={inView ? { opacity: 1, y: 0 } : {}}
            transition={{ duration: 0.8, delay: 0.6 }}
            className="mt-16"
          >
            <h3 className="text-2xl font-bold text-gray-900 mb-8 text-center">
              Ready to Get Started? Contact Us Today
            </h3>

            <div className="grid md:grid-cols-3 gap-8">
              {contactMethods.map((method, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, y: 30 }}
                  animate={inView ? { opacity: 1, y: 0 } : {}}
                  transition={{ duration: 0.6, delay: 0.8 + index * 0.1 }}
                  className="bg-white rounded-2xl p-6 shadow-lg border border-gray-200 text-center hover:shadow-xl transition-shadow duration-300"
                >
                  <div className="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center mx-auto mb-4">
                    <method.icon className="h-8 w-8 text-white" />
                  </div>
                  <h4 className="text-xl font-bold text-gray-900 mb-2">{method.title}</h4>
                  <p className="text-gray-600 mb-4">{method.description}</p>
                  <div className="text-lg font-semibold text-blue-600 mb-4">{method.contact}</div>
                  <button className="w-full bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors font-semibold">
                    {method.action}
                  </button>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Urgency Banner */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={inView ? { opacity: 1, scale: 1 } : {}}
            transition={{ duration: 0.8, delay: 1 }}
            className="mt-12 bg-gradient-to-r from-red-500 to-pink-500 rounded-2xl p-8 text-white text-center"
          >
            <h3 className="text-2xl font-bold mb-4">Limited Time Launch Offer</h3>
            <p className="text-lg mb-6">
              Save 50% on the Azure DevOps Permission Matrix Toolkit. 
              This launch discount won't last long!
            </p>
            <div className="flex items-center justify-center space-x-4 text-sm">
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 bg-white rounded-full animate-pulse"></div>
                <span>Limited quantity available</span>
              </div>
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 bg-white rounded-full animate-pulse"></div>
                <span>Price increases soon</span>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
